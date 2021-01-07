class Tartarus::ArchivableItem
  REQUIRED_ATTRIBUTES_NAMES = %i(model cron queue archive_items_older_than timestamp_field active_job
    archive_with tenant_value_source).freeze
  OPTIONAL_ATTRIBUTES_NAMES = %i(tenants_range tenant_id_field batch_size).freeze

  attr_accessor *(REQUIRED_ATTRIBUTES_NAMES + OPTIONAL_ATTRIBUTES_NAMES)

  def cron=(value)
    Fugit.do_parse_cron(value)

    @cron = value
  end

  def archive_items_older_than=(value)
    raise ":archive_items_older_than must be a lambda" if !value.respond_to?(:call)

    @archive_items_older_than = value
  end

  def tenants_range=(value)
    raise ":tenants_range must be a lambda" if !value.respond_to?(:call)

    @tenants_range = value
  end

  def tenants_range
    return @tenants_range if defined?(@tenants_range)

    @tenants_range ||= -> { [] }
  end

  def tenant_value_source
    return @tenant_value_source if defined?(@tenant_value_source)

    @tenant_value_source ||= :id
  end

  def active_job
    @active_job || false
  end

  def archive_with
    return @archive_with if defined?(@archive_with)

    @archive_with ||= :delete_all
  end

  def batch_size
    return @batch_size if defined?(@batch_size)

    @batch_size ||= 10_000
  end

  def validate!
    validate_presence
  end

  def scope_by_tenant?
    !!tenant_id_field
  end

  def archive_strategy(factory: Tartarus::ArchiveStrategy.new)
    factory.for(archive_with, batch_size: batch_size)
  end

  def for_model?(provided_model_name)
    model.to_s == provided_model_name.to_s
  end

  private

  def validate_presence
    REQUIRED_ATTRIBUTES_NAMES.each do |attribute|
      raise ":#{attribute} must be present" if public_send(attribute).nil?
    end
  end
end
