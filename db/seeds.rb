puts "🌱 Starting Sales Import Seed..."

puts "Clearing existing data..."
Sale.destroy_all
SalesImport.destroy_all
Purchaser.destroy_all
Item.destroy_all
Merchant.destroy_all

seed_files = [
  "sales_import_1.tab",
  "sales_import_2.csv",
  "sales_import_3.tab",
  "sales_import_4.tab",
  "sales_import_5.tab"
]

def attach_import_file(import_record, file_path, filename)
  file = File.open(file_path)

  import_record.import_file.attach(
    io: file,
    filename: filename,
    content_type: 'text/tab-separated-values'
  )

  import_record.reload
  file.close
end

seed_files.each_with_index do |filename, index|
  puts "\n📁 Processing #{filename}..."

  file_path = Rails.root.join('db', 'seeds', 'data', filename)

  unless File.exist?(file_path)
    puts "❌ File not found: #{file_path}"
    next
  end

  sales_import = SalesImport.create!(
    status: :pending,
    total_sales_cents: 0
  )

  attach_import_file(sales_import, file_path, filename)

  unless sales_import.import_file.attached?
    puts "❌ Failed to attach file #{filename}"
    puts "   Sales import errors: #{sales_import.errors.full_messages}" if sales_import.errors.any?
    sales_import.destroy
    next
  end

  puts "✅ File attached successfully"

  service = SalesImport::Create.new(sales_import: sales_import)

  puts "Service valid? #{service.valid?}"
  unless service.valid?
    puts "Service errors: #{service.errors.full_messages}"
    next
  end

  if service.call
    sales_import.reload
    puts "✅ Success! Status: #{sales_import.status}"
    puts "   📊 Total Sales: $#{sales_import.total_sales_cents / 100.0}"
    puts "   📄 Filename: #{sales_import.filename}"
    puts "   🛒 Sales Count: #{sales_import.sales.count}"
  else
    puts "❌ Failed to process #{filename}"
    puts "   Errors: #{service.errors.full_messages.join(', ')}"
  end
end

# Display summary
puts "\n📈 Seeding Summary:"
puts "   SalesImports: #{SalesImport.count}"
puts "   Sales: #{Sale.count}"
puts "   Purchasers: #{Purchaser.count}"
puts "   Items: #{Item.count}"
puts "   Merchants: #{Merchant.count}"

# Display some sample data
puts "\n🔍 Sample Data:"
if Purchaser.any?
  puts "   Purchasers: #{Purchaser.limit(3).pluck(:name).join(', ')}"
end
if Item.any?
  puts "   Items: #{Item.limit(3).pluck(:description).join(', ')}"
end
if Merchant.any?
  puts "   Merchants: #{Merchant.limit(3).pluck(:name).join(', ')}"
end

puts "\n🎉 Seeding completed!"
