class SampleFilesController < ApplicationController
  def show
    filename = params[:filename]
    file_path = Rails.root.join("spec", "fixtures", "files", filename)

    if File.exist?(file_path) && filename.match?(/\A[a-zA-Z0-9_.-]+\z/)
      send_file file_path,
                disposition: "attachment",
                filename: filename,
                type: "text/tab-separated-values"
    else
      head :not_found
    end
  end
end
