-- migrations/1645971838-add_need-sync-gateway.sql
-- :up

create table need_sync_gateway (
  gateway_address text NOT NULL,
  PRIMARY KEY (gateway_address)
);

ALTER TABLE rewards ADD CONSTRAINT "fk_rewards_need_sync_gateway" FOREIGN KEY ("gateway") REFERENCES need_sync_gateway(gateway_address);