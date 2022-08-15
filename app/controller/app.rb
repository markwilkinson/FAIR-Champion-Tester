require 'swagger/blocks'
require 'sinatra/json'
require 'sinatra'
require 'sinatra/base'
# DO NOT change the order of loading below.  The files contain executable code that builds the overall configuration before this module starts
require_relative './configuration.rb'
require_relative './models.rb'
require_relative './routes.rb'

class Swag < Sinatra::Application
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'FAIR Champion Testing Service'
      key :description, 'Tests the metadata of your stuff'
      key :termsOfService, 'https://fairdata.services/Champion/terms/'
      contact do
        key :name, 'Mark D Wilkinson'
        key :organization, 'FAIR Data Systems S.L.'
        key :email, 'info@fairdata.systems'
      end
      license do
        key :name, 'MIT'
      end
    end

    tag do
      key :name, $th.keys.first
      key :description, 'All Tests'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://fairdata.services/Champion/about'
      end
    end
    key :schemes, ["http"]
    key :host, 'fairdata.services:9003'
    key :basePath, '/tests'
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [ ErrorModel, InputScheme, EvalResponse, AllTests, self].freeze

  set_routes(classes: SWAGGERED_CLASSES)

  run! # if app_file == $PROGRAM_NAME

end
