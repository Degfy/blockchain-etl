-module(be_db_txn_actor).

-include("be_db_follower.hrl").
-include("be_db_worker.hrl").

-include_lib("helium_proto/include/blockchain_txn_rewards_v2_pb.hrl").

-behavior(be_db_worker).
-behavior(be_db_follower).

%% be_db_worker
-export([prepare_conn/1]).
%% be_block_handler
-export([init/1, load_block/6]).
%% api
-export([to_actors/1, q_insert_transaction_actors/2]).

-define(S_INSERT_ACTOR, "insert_actor").
-define(S_INSERT_ACTOR_10, "insert_actor_10").
-define(S_INSERT_ACTOR_100, "insert_actor_100").

-record(state, {}).

%%
%% be_db_worker
%%

prepare_conn(Conn) ->
    MkQueryFun = fun(Rows) ->
        epgsql:parse(
            Conn,
            ?S_INSERT_ACTOR ++ "_" ++ integer_to_list(Rows),
            [
                "insert into transaction_actors (block, actor, actor_role, transaction_hash) ",
                "values  ",
                be_utils:make_values_list(4, Rows),
                "on conflict do nothing"
            ],
            []
        )
    end,
    {ok, S1} = MkQueryFun(1),
    {ok, S10} = MkQueryFun(10),
    {ok, S100} = MkQueryFun(100),
    #{
        ?S_INSERT_ACTOR => S1,
        ?S_INSERT_ACTOR_10 => S10,
        ?S_INSERT_ACTOR_100 => S100
    }.

%%
%% be_block_handler
%%

init(_) ->
    {ok, #state{}}.

load_block(Conn, _Hash, Block, _Sync, _Ledger, State = #state{}) ->
    Queries = q_insert_block_transaction_actors(Block),
    execute_queries(Conn, Queries),
    {ok, State}.

execute_queries(Conn, Queries) when length(Queries) > 100 ->
    lists:foreach(
        fun
            (Q) when length(Q) == 100 ->
                %% Can't match 100 in the success case since conflicts are ignored
                {ok, _} = ?PREPARED_QUERY(Conn, ?S_INSERT_ACTOR_100, lists:flatten(Q));
            (Q) ->
                execute_queries(Conn, Q)
        end,
        be_utils:split_list(Queries, 100)
    );
execute_queries(Conn, Queries) when length(Queries) > 10 ->
    lists:foreach(
        fun
            (Q) when length(Q) == 10 ->
                %% Can't match 10 in the success case since conflicts are ignored
                {ok, _} = ?PREPARED_QUERY(Conn, ?S_INSERT_ACTOR_10, lists:flatten(Q));
            (Q) ->
                execute_queries(Conn, Q)
        end,
        be_utils:split_list(Queries, 10)
    );
execute_queries(Conn, Queries) ->
    ok = ?BATCH_QUERY(Conn, [{?S_INSERT_ACTOR, I} || I <- Queries]).

q_insert_transaction_actors(Height, Txn) ->
    TxnHash = ?BIN_TO_B64(blockchain_txn:hash(Txn)),
    lists:map(
        fun({Role, Key}) ->
            [Height, ?BIN_TO_B58(Key), list_to_binary(Role), TxnHash]
        end,
        to_actors(Txn)
    ).

q_insert_block_transaction_actors(Block) ->
    Height = blockchain_block_v1:height(Block),
    Txns = blockchain_block_v1:transactions(Block),
    lists:flatmap(
        fun(Txn) ->
            q_insert_transaction_actors(Height, Txn)
        end,
        Txns
    ).

-spec to_actors(blockchain_txn:txn()) -> [{string(), libp2p_crypto:pubkey_bin()}].
to_actors(T) ->
    to_actors(blockchain_txn:type(T), T).

to_actors(blockchain_txn_gen_gateway_v1, T) ->
    [
        {"gateway", blockchain_txn_gen_gateway_v1:gateway(T)}
    ];
to_actors(blockchain_txn_add_gateway_v1, T) ->
    [
        {"gateway", blockchain_txn_add_gateway_v1:gateway(T)}
    ];
to_actors(blockchain_txn_assert_location_v1, T) ->
    [
        {"gateway", blockchain_txn_assert_location_v1:gateway(T)}
    ];
to_actors(blockchain_txn_assert_location_v2, T) ->
    [
        {"gateway", blockchain_txn_assert_location_v2:gateway(T)}
    ];

to_actors(blockchain_txn_transfer_hotspot_v1, T) ->
    [
        {"gateway", blockchain_txn_transfer_hotspot_v1:gateway(T)}
    ];
to_actors(blockchain_txn_transfer_hotspot_v2, T) ->
    [
        {"gateway", blockchain_txn_transfer_hotspot_v2:gateway(T)}
    ];
to_actors(_X, _Y) ->
   [].

