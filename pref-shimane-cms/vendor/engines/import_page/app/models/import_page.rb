module ImportPage

  class Error < StandardError; end
  class ExtractArchiveError < self::Error; end
  class DataInvalid < self::Error; end

end
