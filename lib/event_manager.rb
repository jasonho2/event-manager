require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'phonelib'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone)
  phone = Phonelib.parse(phone.to_s).sanitized
  if phone.length != 10
    if phone.length < 10
      puts "bad number"
    elsif phone.length == 11
      if phone[0] == "1"
        puts phone[1..11]
      else
        puts "bad number"
      end
    elsif phone.length > 11
      puts "bad number"
    end
  else
    puts phone
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  # removing public civic info key

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def save_phone_numbers(id, phone)
  Dir.mkdir('phone_numbers') unless Dir.exist?('phone_numbers')

  filename = "output/phone_number_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts phone
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])
end
