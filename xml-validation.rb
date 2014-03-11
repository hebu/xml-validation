require 'nokogiri'
require 'open-uri'

unless ARGV.length > 0
  puts "Usage: jruby xml-validation.rb <xml-input-file> <optional-schema-url(s)>"
  return
end

xml_input_file = ARGV[0].to_s
xsd_uris = []
if ARGV.length > 1
  1.upto(ARGV.length) do |idx|
    xsd_uris << ARGV[idx].to_s
  end
end

puts "Validating #{xml_input_file} ..."

File.open(xml_input_file) do |f|
  doc = Nokogiri.XML(f)

  schema_location = doc.root['schemaLocation'] || doc.root['xs:schemaLocation'] || doc.root['xsi:schemaLocation']
  unless schema_location.nil?
    schemata_by_ns = Hash[ schema_location.scan(/(\S+)\s+(\S+)/) ]
    schemata_by_ns.each do |ns, xsd_uri|
      xsd_uris << xsd_uri unless xsd_uris.include?(xsd_uri)
    end
  end

  if xsd_uris.empty?
    puts "No schemas found to validate against..."
    return
  end

  valid = true

  xsd_uris.each do |xsd_uri|
    puts "Validating against #{xsd_uri} ..."

    xsd = Nokogiri::XML::Schema(open(xsd_uri).read)

    unless xsd.valid?(doc)
      puts "File failed XML validation against #{xsd_uri}."
      xsd.validate(doc).each do |syntax_error|
        puts syntax_error
      end
      valid = false
    end
  end

  puts "File is valid." if valid

end