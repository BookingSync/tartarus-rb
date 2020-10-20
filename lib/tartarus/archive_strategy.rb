class Tartarus::ArchiveStrategy
  def for(strategy_name)
    case strategy_name.to_sym
    when :delete_all
      Tartarus::ArchiveStrategy::DeleteAll.new
    when :destroy_all
      Tartarus::ArchiveStrategy::DestroyAll.new
    else
      raise "unknown strategy: #{strategy_name}"
    end
  end
end
