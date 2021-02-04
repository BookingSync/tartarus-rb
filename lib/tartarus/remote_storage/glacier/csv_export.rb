class Tartarus
  module RemoteStorage
    class Glacier
      class CsvExport
        FILE_MODE = "w"
        DELIMITER = ";"
        NO_PATH_FOR_EXPORT = nil
        ENCODING = "UTF-8"
        private_constant :FILE_MODE, :DELIMITER, :NO_PATH_FOR_EXPORT, :ENCODING

        attr_reader :storage_directory, :file_service, :file_utils
        private     :storage_directory, :file_service, :file_utils

        def initialize(storage_directory, file_service: ::File, file_utils: FileUtils)
          @storage_directory = storage_directory
          @file_service = file_service
          @file_utils = file_utils
        end

        def export(collection, path_to_file)
          with_csv_export_file(path_to_file) do |file|
            collection.copy_to(NO_PATH_FOR_EXPORT, delimiter: DELIMITER) do |line|
              file.write(line.force_encoding(ENCODING))
            end
          end
        end

        private

        def with_csv_export_file(path_to_file, &block)
          file_utils.mkdir_p(storage_directory) if !file_service.exist?(storage_directory)

          file_service.open(path_to_file, FILE_MODE, &block)
        end
      end
    end
  end
end
