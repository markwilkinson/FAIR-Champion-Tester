require_relative './routes_helper.rb'

def set_routes(classes: allclasses) # $th is the test configuration hash
  get '/' do
    content_type :json
    logger.info "\n\n\ntest #{$tests_hash}\n\n"
    json Swagger::Blocks.build_root_json(classes)
  end

  post '/tests/execute_all' do
    content_type "application/ld+json"
    params = JSON.parse(request.body.read, symbolize_names: true)
    fsp_only = false
    fsp_only = true if params[:fsp_only] and params[:fsp_only] == "true"
    logger.info "\nexecuting all using signposting only #{fsp_only.to_s}\n"
    metadatas = harvest_and_execute(params: params, fsp_only: fsp_only)
    g = build_champion_result(metadatas: metadatas)
    g.dump(:jsonld)
  end

  $tests_hash.each do |_id, val|
    #warn  "/tests/#{val['operation_path']}"
    get "/tests/#{val['operation_path']}" do
      content_type :json
      json Swagger::Blocks.build_root_json(classes)
    end


    # do a bit of ruby metaprogramming here...
    # const_get will return the Class object that is represented by the 
    # classname string in the config file
    post "/tests/#{val['operation_path']}" do
      content_type "application/ld+json"
      params = JSON.parse(request.body.read, symbolize_names: true)
      fsp_only = false
      fsp_only = true if params[:fsp_only] and params[:fsp_only] == "true"
      logger.info "\nexecuting all using signposting only #{fsp_only.to_s}\n"
      metadata = harvest_and_execute(params: params, fsp_only: fsp_only, test: [val])
      g = build_result(metadata: metadata)
      g.dump(:jsonld)
    end
  end

end


# TODO  put these in a different object

