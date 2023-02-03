//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

/// `DataStoreList<ModelType>` is a DataStore-aware custom `Collection` that is capable of loading
/// records from the `DataStore` on-demand. This is especially useful when dealing with
/// Model associations that need to be lazy loaded.
///
/// When using `DataStore.query(_ modelType:)` some models might contain associations
/// with other models and those aren't fetched automatically. This collection keeps track
/// of the associated `id` and `field` and fetches the associated data on demand.
public class DataStoreListProvider<Element: Model>: ModelListProvider {

    var loadedState: ModelListProviderState<Element>

    init(metadata: DataStoreListDecoder.Metadata) {
        self.loadedState = .notLoaded(associatedIdentifiers: metadata.dataStoreAssociatedIdentifiers,
                                      associatedFields: metadata.dataStoreAssociatedFields)
    }

    init(_ elements: [Element]) {
        self.loadedState = .loaded(elements)
    }
    
    public func getState() -> ModelListProviderState<Element> {
        switch loadedState {
        case .notLoaded(let associatedIdentifiers, let associatedFields):
            return .notLoaded(associatedIdentifiers: associatedIdentifiers, associatedFields: associatedFields)
        case .loaded(let elements):
            return .loaded(elements)
        }
    }
    
    public func load() async throws -> [Element] {
        switch loadedState {
        case .loaded(let elements):
            return elements
        case .notLoaded(let associatedIdentifiers, let associatedFields):
            let predicate: QueryPredicate
            if associatedIdentifiers.count == 1,
               let associatedId = associatedIdentifiers.first,
               let associatedField = associatedFields.first {
                self.log.verbose("Loading List of \(Element.schema.name) by \(associatedField) == \(associatedId) ")
                predicate = field(associatedField) == associatedId
            } else {
                let predicateValues = resolveAssociatedFieldsAndValues(fields: associatedFields,
                                                                       values: associatedIdentifiers)
                var queryPredicates: [QueryPredicateOperation] = []
                for (identifierName, identifierValue) in predicateValues {
                    queryPredicates.append(QueryPredicateOperation(field: identifierName,
                                                                   operator: .equals(identifierValue)))
                }
                self.log.verbose("Loading List of \(Element.schema.name) by \(associatedFields) == \(associatedIdentifiers) ")
                predicate = QueryPredicateGroup(type: .and, predicates: queryPredicates)
            }
            
            do {
                let elements = try await Amplify.DataStore.query(Element.self, where: predicate)
                self.loadedState = .loaded(elements)
                return elements
            } catch let error as DataStoreError {
                self.log.error(error: error)
                throw CoreError.listOperation("Failed to Query DataStore.",
                                              "See underlying DataStoreError for more details.",
                                              error)
            } catch {
                throw error
                
            }
        }
    }

    public func hasNextPage() -> Bool {
        false
    }
    
    public func getNextPage() async throws -> List<Element> {
        throw CoreError.clientValidation("There is no next page.",
                                         "Only call `getNextPage()` when `hasNextPage()` is true.",
                                         nil)
    }
    
    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded(let associatedIdentifiers,
                        let associatedFields):
            let metadata = DataStoreListDecoder.Metadata(dataStoreAssociatedIdentifiers: associatedIdentifiers,
                                                         dataStoreAssociatedFields: associatedFields)
            var container = encoder.singleValueContainer()
            try container.encode(metadata)
        case .loaded(let elements):
            try elements.encode(to: encoder)
        }
    }
    
    // MARK: - Helpers
    
    func resolveAssociatedFieldsAndValues(fields associatedFields: [String],
                                          values associatedIdentifiers: [String]) -> Zip2Sequence<[String], [String]> {
        if let associatedField = associatedFields.first {
            // If the number of fields and identifier values do not match, try to resolve the remaining
            // fields through this schema (the child model)'s indexes. When the parent's primary key is a composite
            // key, there is a codegen issue where the remaining index of the parent's primary key isn't added. This is
            // a workaround in place to look for a corresponding set of index fields. Ideally, the codegen model
            // process adds all the associated fields, but there is a known issue here:
            // https://github.com/aws-amplify/amplify-codegen/issues/539
            let resolvedAssociatedFields = Element.schema.indexes.compactMap { modelAttribute in
                if case .index(let fields, _) = modelAttribute,
                   fields.contains(where: { $0 == associatedField }) {
                    return fields
                } else {
                    return nil
                }
            }.first ?? associatedFields
            return zip(resolvedAssociatedFields, associatedIdentifiers)
        }
        
        return zip(associatedFields, associatedIdentifiers)
    }
}

extension DataStoreListProvider: DefaultLogger { }
