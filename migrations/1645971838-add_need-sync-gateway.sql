-- migrations/1645971838-add_need-sync-gateway.sql
-- :up

create table need_sync_gateway (
  gateway_address text NOT NULL,
  PRIMARY KEY (gateway_address)
);


ALTER TABLE gateway_inventory ADD CONSTRAINT "fk_gateway_inventory_need_sync_gateway" FOREIGN KEY ("address") REFERENCES need_sync_gateway (gateway_address);

ALTER TABLE gateway_inventory ADD CONSTRAINT "fk_gateway_inventory_account_inventory" FOREIGN KEY ("owner") REFERENCES account_inventory (address);

ALTER TABLE rewards ADD CONSTRAINT "fk_rewards_need_sync_gateway" FOREIGN KEY ("gateway") REFERENCES need_sync_gateway(gateway_address);

ALTER TABLE gateways ADD CONSTRAINT "fk_gateway_need_sync_gateway" FOREIGN KEY ("address") REFERENCES need_sync_gateway (gateway_address);