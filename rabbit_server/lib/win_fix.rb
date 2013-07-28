class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def supports_ddl_transactions?
    false
  end
end
