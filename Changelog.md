# Changelog

## Master

## 0.8.0

- Remove explicit ordering from both `Tartarus::ArchivableCollectionRepository#items_older_than` and `Tartarus::ArchivableCollectionRepository#items_older_than_for_tenant`

## 0.7.0

- Remove explicit ordering from `Tartarus::ArchivableCollectionRepository#items_older_than`, it increased the cost of queries significantly on large tables

## 0.6.0

- Optimize query from `Tartarus::ArchivableCollectionRepository#items_older_than` by adding explicit ordering

## 0.5.0

- Provide ability to explicitly set the name of archivable item to have multiple ways of archiving the same model

## 0.4.1

- Do not make Glacier a required dependency if not used

## 0.4.0

- Add Glacier remote storage support to upload data before deleting it

## 0.3.0

- Add `delete_all_using_limit_in_batches` strategy

## 0.2.0
- Add support for deleting and destroying in batches
- Add integration tests with a real database and ActiveRecord
- Better docs

## 0.1.0
- Initial release
