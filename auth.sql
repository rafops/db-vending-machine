DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles
    WHERE  rolname = 'db_vending') THEN

    CREATE USER db_vending;
    GRANT rds_iam TO db_vending;
  END IF;
END
$$;
