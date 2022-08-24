require 'fsp_harvester' # provides SPARQL and various constants
require 'sparql'

class Gen3_persistent_data_identifier

    def self.run_test(metadata:)
        result1 = check_links(metadata: metadata)
        result2 = check_ld(metadata: metadata)
        if result1 or result2
            metadata.score = 1
            metadata.comments << "SUCCESS: a persistent data identifier was found"
        else
            metadata.comments << "FAILURE: a persistent data identifier was not found"
        end
        warn "score is #{metadata.score}"
        metadata
    end


    def self.check_ld(metadata:)
        graph = metadata.graph
        sparql_values = ""
        FspHarvester::DATA_PREDICATES.each do |p|
            metadata.comments << "INFO: testing predicate #{p}"
            next unless p
            sparql_values += " <#{p}>"
        end
        query = "SELECT ?o WHERE {
            ?s ?p ?o .
            VALUES ?p {#{sparql_values}}
        }"
        warn "query " + query
        query = SPARQL.parse(query)
        results = query.execute(graph)
        unless results.first
          metadata.comments << "INFO: no results found when testing ld predicates"
          return false
        end
        if results.length > 1
          ids = results.map {|r| r[:o]}
          if ids.uniq.length > 1
            metadata.add_warning(["600", "", ""])
            metadata.comments << "WARN: multiple matches for potential identifiers.  Ambiguity is bad."
            return false
          end
        end
        FspHarvester::GUID_TYPES.each do |type, regex|
          metadata.comments << "INFO: testing #{results.first[:o]} against regexp for #{type}"
          return true if results.first[:o] =~ regex # only one result
        end
        metadata.comments << "WARN: #{results.first[:o]} does not match known persistence schemes"
        return false
    end

    def self.check_links(metadata:)
      metadata.comments << "INFO: testing cite-as links for exactly one that must also be persistent"
      links = metadata.links
      citeas = links.select {|l| l.relation == 'cite-as'}
      if citeas.length > 1
          metadata.add_warning(["600", "", ""])
          metadata.comments << "WARN: multiple matches for potential data identifiers.  Ambiguity is bad."
          return false
      end
      c = citeas.first
      FspHarvester::GUID_TYPES.each do |type, regex|
          metadata.comments << "INFO: testing #{c} against regexp for #{type}"
          return true if c =~ regex
      end
      metadata.comments << "WARN: #{c} does not match known persistence schemes"
      return false
    end

    # GUID_TYPES = { 
    #     'inchi' => Regexp.new(/^\w{14}-\w{10}-\w$/),
    #     'doi' => Regexp.new(%r{^10.\d{4,9}/[-._;()/:A-Z0-9]+$}i),
    #     'handle1' => Regexp.new(%r{^[^/]+/[^/]+$}i),
    #     'handle2' => Regexp.new(%r{^\d{4,5}/[-._;()/:A-Z0-9]+$}i), # legacy style  12345/AGB47A
    #     'uri' => Regexp.new(%r{^\w+:/?/?[^\s]+$}),
    #     'ark' => Regexp.new(%r{^ark:/[^\s]+$}) 
    #   }
    
    # DATA_PREDICATES = [
#   'http://www.w3.org/ns/ldp#contains',
#   'http://xmlns.com/foaf/0.1/primaryTopic',
#   'http://purl.obolibrary.org/obo/IAO_0000136', # is about
#   'http://purl.obolibrary.org/obo/IAO:0000136', # is about (not the valid URL...)
#   'https://www.w3.org/ns/ldp#contains',
#   'https://xmlns.com/foaf/0.1/primaryTopic',

#   'http://schema.org/mainEntity',
#   'http://schema.org/codeRepository',
#   'http://schema.org/distribution',
#   'https://schema.org/mainEntity',
#   'https://schema.org/codeRepository',
#   'https://schema.org/distribution',

#   'http://www.w3.org/ns/dcat#distribution',
#   'https://www.w3.org/ns/dcat#distribution',
#   'http://www.w3.org/ns/dcat#dataset',
#   'https://www.w3.org/ns/dcat#dataset',
#   'http://www.w3.org/ns/dcat#downloadURL',
#   'https://www.w3.org/ns/dcat#downloadURL',
#   'http://www.w3.org/ns/dcat#accessURL',
#   'https://www.w3.org/ns/dcat#accessURL',

#   'http://semanticscience.org/resource/SIO_000332', # is about
#   'http://semanticscience.org/resource/is-about', # is about
#   'https://semanticscience.org/resource/SIO_000332', # is about
#   'https://semanticscience.org/resource/is-about', # is about
#   'https://purl.obolibrary.org/obo/IAO_0000136' # is about
# ]
end