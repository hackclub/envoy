class PdfGeneratorService
  def initialize(application)
    @application = application
    @template = application.event.effective_letter_template
  end

  def generate
    return nil unless @template

    html_content = render_html
    generate_pdf(html_content)
  end

  private

  def generate_pdf(html)
    pdf_content = Grover.new(html, **pdf_options).to_pdf
    lock_pdf(pdf_content)
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

  def pdf_options
    {
      format: "Letter",
      margin: {
        top: "0",
        bottom: "0",
        left: "0",
        right: "0"
      },
      print_background: true
    }
  end

  def render_html
    ApplicationController.renderer.render(
      template: "pdf/visa_letter",
      layout: "pdf",
      assigns: {
        application: @application,
        participant: @application.participant,
        event: @application.event,
        template: @template,
        rendered_body: @template.render(@application),
        letterhead_data_uri: letterhead_data_uri,
        signature_data_uri: signature_data_uri,
        default_logo_data_uri: default_logo_data_uri,
        default_signature_data_uri: default_signature_data_uri,
        verification_qr_svg: verification_qr_svg
      }
    )
  end

  def letterhead_data_uri
    return nil unless @template.letterhead_image.attached?

    blob = @template.letterhead_image.blob
    base64 = Base64.strict_encode64(blob.download)
    "data:#{blob.content_type};base64,#{base64}"
  rescue StandardError => e
    Rails.logger.error("Failed to encode letterhead: #{e.message}")
    nil
  end

  def signature_data_uri
    return nil unless @template.signature_image.attached?

    blob = @template.signature_image.blob
    base64 = Base64.strict_encode64(blob.download)
    "data:#{blob.content_type};base64,#{base64}"
  rescue StandardError => e
    Rails.logger.error("Failed to encode signature: #{e.message}")
    nil
  end

  def default_logo_data_uri
    logo_path = Rails.root.join("public/images/Hackfoundation.png")
    return nil unless File.exist?(logo_path)

    base64 = Base64.strict_encode64(File.read(logo_path))
    "data:image/png;base64,#{base64}"
  rescue StandardError => e
    Rails.logger.error("Failed to encode default logo: #{e.message}")
    nil
  end

  def default_signature_data_uri
    signature_path = Rails.root.join("public/images/zach-signature.png")
    return nil unless File.exist?(signature_path)

    base64 = Base64.strict_encode64(File.read(signature_path))
    "data:image/png;base64,#{base64}"
  rescue StandardError => e
    Rails.logger.error("Failed to encode default signature: #{e.message}")
    nil
  end

  def verification_qr_svg
    verification_url = "https://hack.club/visa-verify?code=#{@application.verification_code}"
    qr = RQRCode::QRCode.new(verification_url)
    qr.as_svg(
      color: "333",
      shape_rendering: "crispEdges",
      module_size: 2,
      standalone: true,
      use_path: true
    )
  rescue StandardError => e
    Rails.logger.error("Failed to generate QR code: #{e.message}")
    nil
  end
end
