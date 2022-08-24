def harvest_and_execute(params:, fsp_only: false, test: ["all"])
  to_test = []
  if test.first == "all"
    $tests_hash.each do |_id, val|
      to_test << val
    end
  else
    test.each do |testid|
      to_test << $tests_hash[testid]
    end
  end

  metadata = harvest_metadata( 
    tested_guid: params[:guid], 
    fsp_only: fsp_only)

  results = Hash.new
  to_test.each do |val|
    thismeta = clone_metadata_object(old: metadata)
    thismeta.id = create_test_id(test_guid: val['guid'], tested_guid: thismeta.tested_guid, metadata: thismeta)
    hrvst = FspHarvester::VERSION
    version_string = "FspHarvester-#{hrvst}:#{val['version']}"
    thismeta.version = version_string
    thismeta.comments.unshift "INFO: TEST VERSION #{version_string}\n"
    thismeta.comments << "END_OF_HARVESTING"
    # now run the test
    testclass = Object.const_get(val['classname'])
    testclass.run_test(metadata: thismeta)
    #warn "result in the end is: #{metadata}"
    results[val['guid']] = thismeta
  end
  warn "keys: #{results.keys.length}"
  # g = build_champion_result(metadatas: results)  # done in routes
  results
end

def clone_metadata_object(old: )
  newmeta = HarvesterTools::MetadataObject.new
  newmeta.date = old.date
  newmeta.comments.append(*old.comments)
  newmeta.warnings.append(*old.warnings)
  newmeta.tested_guid = old.tested_guid
  newmeta.graph = old.graph
  newmeta.hash.merge(old.hash)
  newmeta.all_uris.append(*old.all_uris)
  newmeta.links.append(*old.links)
  newmeta
end

def harvest_metadata(tested_guid:, fsp_only: false)
  warn "\n\nnow harvesting #{tested_guid}\n\n"
  metadata = HarvesterTools::MetadataObject.new  # initialize to set the date
  metadata.tested_guid = tested_guid
  
  _links, metadata = HarvesterTools::Utils.resolve_guid(guid: tested_guid, metadata: metadata)
  #warn "harvesting result #{_links}\n\n#{metadata}\n\n"
  metadata = HarvesterTools::BruteForce.begin_brute_force(guid: tested_guid, metadata: metadata) unless fsp_only
  metadata
end

def create_test_id(test_guid: "urn:local:unidentified_metadata", tested_guid:, metadata:)
  test_result_id = test_guid + "#" + tested_guid.to_s + "/result-" + metadata.date.to_s
  test_result_id
end


def build_champion_result(metadatas:)

  finalgraph = RDF::Graph.new
  metadatas.each_key do |testid|
    thismeta = metadatas[testid]
    warn "RESULTS #{testid}#{thismeta}\n\n"
    warn "RESULTSss #{metadatas.keys}\n\n"

    resultgraph = build_result(metadata: thismeta)
    finalgraph << resultgraph
    resultid = thismeta.id
    harvester_triplify(testid, "http://semanticscience.org/resource/SIO:000229", resultid, finalgraph )
  end
  finalgraph
end



def build_result(metadata:)
    m = metadata
    g = RDF::Graph.new
    warn "RESULT!! #{m}\n\n"

    resultid = m.id
    harvester_triplify(resultid, RDF.type,"http://fairmetrics.org/resources/metric_evaluation_result", g )
    harvester_triplify(resultid,  "http://semanticscience.org/resource/SIO_000300",m.score, g )
    harvester_triplify(resultid,  "http://purl.obolibrary.org/obo/date",m.date, g )
    harvester_triplify(resultid,  "http://schema.org/softwareVersion",m.version, g )
    harvester_triplify(resultid,  "http://schema.org/comment",m.comments.to_s, g )
    harvester_triplify(resultid,  "http://semanticscience.org/resource/SIO_000332",m.tested_guid, g )
    harvester_triplify(resultid,  "http://www.w3.org/2000/10/swap/log#semanticsOrError",m.warnings.to_json.to_s, g )
    #warn "dumping result #{g.dump(:jsonld)}"
    g
end

# [
#     {
#     "@id": "http://w3id.org/FAIR_Tests/tests/gen2_unique_identifier#10.5281/zenodo.1147435/result-2018-12-31T13:32:43+00:00",
#     "@type": [
#         "http://fairmetrics.org/resources/metric_evaluation_result"
#     ],
#     "http://purl.obolibrary.org/obo/date": [
#         {
#         "@value": "2018-12-31T13:32:43+00:00",
#         "@type": "http://www.w3.org/2001/XMLSchema#date"
#         }
#     ],
#     "http://schema.org/softwareVersion": [
#         {
#         "@value": "Hvst-1.0.1:Tst-0.2.2",
#         "@type": "http://www.w3.org/2001/XMLSchema#float"
#         }
#     ],
#     "http://schema.org/comment": [
#         {
#         "@value": "Found a DOI - pass",
#         "@language": "en"
#         }
#     ],
#     "http://semanticscience.org/resource/SIO_000332": [
#         {
#         "@value": "10.5281/zenodo.1147435",
#         "@language": "en"
#         }
#     ],
#     "http://semanticscience.org/resource/SIO_000300": [
#         {
#         "@value": "1.0",
#         "@type": "http://www.w3.org/2001/XMLSchema#float"
#         }
#     ]
#     }
# ]




# A utility function that SHOULD NOT BE CALLED EXTERNALLY
#
# @param s - subject node
# @param p - predicate node
# @param o - object node
# @param repo - an RDF::Graph object
def harvester_triplify(s, p, o, repo)

    if s.class == String
            s = s.strip
    end
    if p.class == String
            p = p.strip
    end
    if o.class == String
            o = o.strip
    end
    
    unless s.respond_to?('uri')
      
      if s.to_s =~ /^\w+:\/?\/?[^\s]+/
              s = RDF::URI.new(s.to_s)
      else
        abort "Subject #{s.to_s} must be a URI-compatible thingy"
      end
    end
    
    unless p.respond_to?('uri')
  
      if p.to_s =~ /^\w+:\/?\/?[^\s]+/
              p = RDF::URI.new(p.to_s)
      else
        abort "Predicate #{p.to_s} must be a URI-compatible thingy"
      end
    end
  
    unless o.respond_to?('uri')
      if o.to_s =~ /\A\w+:\/?\/?\w[^\s]+/
              o = RDF::URI.new(o.to_s)
      elsif o.to_s =~ /^\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d/
              o = RDF::Literal.new(o.to_s, :datatype => RDF::XSD.date)
      elsif o.to_s =~ /^[+-]?\d+\.\d+$/
              o = RDF::Literal.new(o.to_s, :datatype => RDF::XSD.float)
      elsif o.to_s =~ /^[+-]?[0-9]+$/
              o = RDF::Literal.new(o.to_s, :datatype => RDF::XSD.int)
      else
              o = RDF::Literal.new(o.to_s, :language => :en)
      end
    end
  
    triple = RDF::Statement(s, p, o) 
    repo.insert(triple)
  
    return true
end
  
  