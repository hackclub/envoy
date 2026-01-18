namespace :pdf do
  desc "Lock existing PDFs to prevent editing"
  task lock_existing: :environment do
    applications = VisaLetterApplication.where.associated(:letter_pdf_attachment)

    puts "Found #{applications.count} applications with PDFs to process"

    applications.find_each.with_index do |application, index|
      print "Processing #{index + 1}/#{applications.count}: #{application.reference_number}... "

      begin
        original_pdf = application.letter_pdf.download
        locked_pdf = lock_pdf(original_pdf)

        application.letter_pdf.attach(
          io: StringIO.new(locked_pdf),
          filename: application.letter_pdf.filename.to_s,
          content_type: "application/pdf"
        )

        puts "✓"
      rescue => e
        puts "✗ Error: #{e.message}"
      end
    end

    puts "Done!"
  end

  def lock_pdf(pdf_content)
    doc = HexaPDF::Document.new(io: StringIO.new(pdf_content))
    doc.encrypt(
      user_password: "",
      owner_password: SecureRandom.hex(32),
      permissions: [ :copy_content, :print, :high_quality_print ],
      algorithm: :aes,
      key_length: 128
    )
    output = StringIO.new
    doc.write(output)
    output.string
  end
end
