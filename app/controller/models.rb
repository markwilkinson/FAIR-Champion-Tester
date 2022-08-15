class ErrorModel  # Notice, this is just a plain ruby object.
  include Swagger::Blocks

  swagger_schema :ErrorModel do
    key :required, %i[code message]
    property :code do
      key :type, :integer
      key :format, :int32
    end
    property :message do
      key :type, :string
    end
  end
end

class InputScheme # Notice, this is just a plain ruby object.
  include Swagger::Blocks

  swagger_schema :InputScheme do
    key :required, %i[guid]
    property :guid do
      key :type, :string
    end
  end
end

class EvalResponse # Notice, this is just a plain ruby object.
  include Swagger::Blocks

  swagger_schema :EvalResponse do
    key :required, %i[placeholder]  # figure out output structure
    property :placeholder do
      key :type, :integer
      key :format, :int32
    end
  end
end


class AllTests
  include Swagger::Blocks
  $tests_hash.each do |guid, val|
    swagger_path "/#{val['path']}" do
      operation :post do
        key :description, (val['description']).to_s
        key :version, val['version'].to_s
        key 'x-identifier', guid
        key :operationId, "#{guid}_execute"
        key :tags, [(val['title']).to_s]
        key 'x-applies_to_principle', val['applies_to_principle'].to_s
        key 'x-tests-metric', val['tests_metric'].to_s
        key 'x-author-name', [(val['responsible_developer']).to_s]
        key 'email', [(val['email']).to_s]
        key 'x-author-id', [(val['developer_ORCiD']).to_s]
        key 'x-organization', [(val['organization']).to_s]
        key 'x-org-url', [(val['org_url']).to_s]
        key :produces, [
          'application/ld+json'
        ]
        key :consumes, [
          'application/ld+json'
        ]
        parameter do
          key :name, :guid
          key :in, :body
          key :description, 'The GUID to test'
          key :required, true
          schema do
            key :'$ref', :InputScheme
          end
        end
        response 200 do
          key :description, 'Test Response'
          schema do
            key :'$ref', :EvalResponse
          end
        end
        response :default do
          key :description, 'unexpected error'
          schema do
            key :'$ref', :ErrorModel
          end
        end
      end
    end
  end
end
