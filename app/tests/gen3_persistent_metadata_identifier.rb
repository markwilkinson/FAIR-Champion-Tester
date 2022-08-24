require 'fsp_harvester' # provides SPARQL and various constants
require 'sparql'

class Gen3_persistent_metadata_identifier

    def self.run_test(metadata:)
        result1 = check_links(metadata: metadata)
        result2 = check_ld(metadata: metadata)
        if result1 or result2
            metadata.comments << "SUCCESS: a persistent data identifier was found"
        else
            metadata.comments << "FAKLURE: a persistent data identifier was not found"
        end
        warn "score is #{metadata.score}"
        metadata
    end


    def self.check_ld(metadata:)
        graph = metadata.graph
        sparql_values = ""
        FspHarvester::SELF_IDENTIFIER_PREDICATES.each do |p|
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
        return false
    end

    def self.check_links(metadata:)
      metadata.comments << "INFO: testing describedby links for at least one that is persistent"
      links = metadata.links
        db = links.select {|l| l.relation == 'describedby'}
        success = false
        db.each do |link|
          FspHarvester::GUID_TYPES.each do |type, regex|
              metadata.comments << "INFO: testing #{link.href} against regexp for #{type}"
              success = true if link.href =~ regex
          end
          metadata.comments << "WARN: #{link.href} does not match known persistence schemes"
        return success
      end
    end

    # GUID_TYPES = { 
    #     'inchi' => Regexp.new(/^\w{14}-\w{10}-\w$/),
    #     'doi' => Regexp.new(%r{^10.\d{4,9}/[-._;()/:A-Z0-9]+$}i),
    #     'handle1' => Regexp.new(%r{^[^/]+/[^/]+$}i),
    #     'handle2' => Regexp.new(%r{^\d{4,5}/[-._;()/:A-Z0-9]+$}i), # legacy style  12345/AGB47A
    #     'uri' => Regexp.new(%r{^\w+:/?/?[^\s]+$}),
    #     'ark' => Regexp.new(%r{^ark:/[^\s]+$}) 
    #   }
    
    # SELF_IDENTIFIER_PREDICATES = [
    #     'http://purl.org/dc/elements/1.1/identifier',
    #     'https://purl.org/dc/elements/1.1/identifier',
    #     'http://purl.org/dc/terms/identifier',
    #     'http://schema.org/identifier',
    #     'https://purl.org/dc/terms/identifier',
    #     'https://schema.org/identifier'
    #   ]
end