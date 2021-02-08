require "delegate"

class Tartarus
  module RemoteStorage
    class Glacier
      class File < SimpleDelegator
        def description
          file_service.basename(self, ".*")
        end

        def body
          self
        end

        def checksum
          Digest::SHA256.file(path)
        end

        def delete_from_local_storage
          file_service.delete(path)
        end

        private

        def file_service
          ::File
        end
      end
    end
  end
end
