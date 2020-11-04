class Tartarus::ArchiveStrategy
  def for(strategy_name)
    case strategy_name.to_sym
    when :delete_all
      Tartarus::ArchiveStrategy::DeleteAll.new
    when :destroy_all
      Tartarus::ArchiveStrategy::DestroyAll.new
    when :delete_all_without_batches
      Tartarus::ArchiveStrategy::DeleteAllWithoutBatches.new
    when :destroy_all_without_batches
      Tartarus::ArchiveStrategy::DestroyAllWithoutBatches.new
    else
      raise "unknown strategy: #{strategy_name}"
    end
  end
end
