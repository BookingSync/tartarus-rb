class Tartarus::ArchiveStrategy
  def for(strategy_name, batch_size: 0)
    case strategy_name.to_sym
    when :delete_all
      Tartarus::ArchiveStrategy::DeleteAll.new
    when :destroy_all
      Tartarus::ArchiveStrategy::DestroyAll.new
    when :delete_all_without_batches
      Tartarus::ArchiveStrategy::DeleteAllWithoutBatches.new
    when :destroy_all_without_batches
      Tartarus::ArchiveStrategy::DestroyAllWithoutBatches.new
    when :delete_all_using_limit_in_batches
      Tartarus::ArchiveStrategy::DeleteAllUsingLimitInBatches.new(batch_size: batch_size)
    else
      raise "unknown strategy: #{strategy_name}"
    end
  end
end
