-- Grain guarantee 
CREATE UNIQUE INDEX IF NOT EXISTS ux_item_facts_order_item ON mart.item_facts (order_id, order_item_id);

--Common filters / joins
CREATE INDEX IF NOT EXISTS idx_item_facts_order_id ON mart.item_facts (order_id);

CREATE INDEX IF NOT EXISTS idx_item_facts_purchase_date
  ON mart.item_facts (purchase_date);

CREATE INDEX IF NOT EXISTS idx_item_facts_customer_id
  ON mart.item_facts (customer_id);

CREATE INDEX IF NOT EXISTS idx_item_facts_product_id
  ON mart.item_facts (product_id);

CREATE INDEX IF NOT EXISTS idx_item_facts_seller_id
  ON mart.item_facts (seller_id);

ANALYZE mart.item_facts;