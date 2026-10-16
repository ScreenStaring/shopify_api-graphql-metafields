# frozen_string_literal: true

module ShopifyAPI
  module GraphQL
    module Metafields
      class Definition < Request
        GET = <<-GQL
          query MetafieldsCount($id: ID $identifier: MetafieldDefinitionIdentifierInput) {
            metafieldDefinition(id: $id identifier: $identifier) {
              %s
            }
          }
        GQL

        DEFAULT_GET_FIELDS = %w[id namespace key owner_type name description type { name }].freeze

        CREATE =<<-GQL
          mutation CreateMetafieldDefinition($definition: MetafieldDefinitionInput!) {
            metafieldDefinitionCreate(definition: $definition) {
              createdDefinition { %s }
              #{Metafields::USER_ERRORS}
            }
          }
        GQL

        DEFAULT_CREATE_FIELDS = DEFAULT_GET_FIELDS.dup

        UPDATE =<<-GQL
          mutation UpdateMetafieldDefinition($definition: MetafieldDefinitionUpdateInput!) {
            metafieldDefinitionUpdate(definition: $definition) {
              updatedDefinition { %s }
              #{Metafields::USER_ERRORS}
            }
          }
        GQL

        DEFAULT_UPDATE_FIELDS = DEFAULT_CREATE_FIELDS.dup.freeze

        DELETE =<<-GQL
          mutation DeleteMetafieldDefinition($id: ID $identifier: MetafieldDefinitionIdentifierInput $deleteMetafields: Boolean) {
            metafieldDefinitionDelete(
              id: $id
              identifier: $identifier
              deleteAllAssociatedMetafields: $deleteMetafields
            ) {
              %s
              #{Metafields::USER_ERRORS}
            }
          }
        GQL

        DEFAULT_DELETE_FIELDS =<<-GQL
          deletedDefinitionId
          deletedDefinition {
            key
            namespace
            ownerType
          }
        GQL

        def create(definition, options = nil)
          fields = options&.dig(:fields) || DEFAULT_CREATE_FIELDS

          result = execute(
            sprintf(CREATE, field_string(fields)),
            :definition => definition
          ).dig(:data, :metafield_definition_create)

          # We can use #except after 2.7
          result.delete(:user_errors)
          result
        end

        def delete(id_or_identifier, options = nil)
          fields = options&.dig(:fields) || DEFAULT_DELETE_FIELDS

          result = execute(
            sprintf(DELETE, field_string(fields)),
            id_key(id_or_identifier) => id_or_identifier,
            :delete_metafields => options && options[:delete_metafields] == true
          ).dig(:data, :metafield_definition_delete)

          # We can use #except after 2.7
          result.delete(:user_errors)
          result
        end

        def get(id_or_identifier, options = nil)
          fields = options&.dig(:fields) || DEFAULT_GET_FIELDS

          execute(
            sprintf(GET, field_string(fields)),
            id_key(id_or_identifier) => id_or_identifier,
          ).dig(:data, :metafield_definition)
        end

        def update(definition, options = nil)
          fields = options&.dig(:fields) || DEFAULT_UPDATE_FIELDS

          result = execute(
            sprintf(UPDATE, field_string(fields)),
            :definition => definition
          ).dig(:data, :metafield_definition_update)

          # We can use #except after 2.7
          result.delete(:user_errors)
          result
        end

        private

        def id_key(id_or_identifier)
          id_or_identifier.is_a?(Hash) ? :identifier : :id
        end
      end
    end
  end
end
