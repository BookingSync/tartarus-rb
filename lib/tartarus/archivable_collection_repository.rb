class Tartarus
  class ArchivableCollectionRepository
    attr_reader :const_resolver
    private     :const_resolver

    def initialize(const_resolver: Object)
      @const_resolver = const_resolver
    end

    def items_older_than_for_tenant(model_name, timestamp_field, timestamp, tenant_id_field, tenant_id)
      collection = collection_for(model_name)
      ensure_column_exists(collection, model_name, timestamp_field)
      ensure_column_exists(collection, model_name, tenant_id_field)

      collection.where("#{timestamp_field} < ?", timestamp).where(tenant_id_field => tenant_id)
                .order(tenant_id_field, timestamp_field)
    end

    def items_older_than(model_name, timestamp_field, timestamp)
      collection = collection_for(model_name)
      ensure_column_exists(collection, model_name, timestamp_field)

      collection.where("#{timestamp_field} < ?", timestamp)
    end

    private

    def collection_for(model_name)
      const_resolver.const_get(model_name.to_s)
    end

    def ensure_column_exists(collection, model_name, column)
      collection.column_names.include?(column.to_s) or raise "column :#{column} does not exist for #{model_name}"
    end
  end
end
