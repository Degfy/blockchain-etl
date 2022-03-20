-- migrations/1647086880802-drop-table.sql
-- :up

DROP TABLE accounts;

DROP TABLE block_signatures;

DROP TABLE dc_burns;

DROP TABLE packets;

ALTER TABLE rewards DROP CONSTRAINT "rewards_transaction_hash_fkey";
ALTER TABLE transaction_actors DROP CONSTRAINT "transaction_actors_transaction_hash_fkey";

DROP TABLE transactions;

delete from transaction_actors where actor_role != 'gateway';

drop trigger gateway_inventory_insert on gateway_inventory;
drop function gateway_inventory_on_insert;