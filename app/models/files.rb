#coding: UTF-8
class Files < ActiveRecord::Base
  require "fileutils"
  
  attr_accessible :session_id, :uploaded_file, :file_limits
  attr_protected  :name, :original_name, :uploaded_at, :size
  attr_accessor   :file_limits, :uploaded_file

  before_validation :is_file?, on: :create
  before_create     :validation_file
  after_create      :validation_upload
  before_destroy    :validation_deleted


  def extention
    if original_name.index(".")
      original_name.split(".").last.downcase
    else
      ""
    end
  end
  
  def is_file?
    return (uploaded_at != nil && name != '') || (defined?(uploaded_file) && uploaded_file.is_a?(ActionDispatch::Http::UploadedFile) )
  end

  def is_image?
    ["jpg", "jpeg", "gif", "png"].include? extention
  end

  def is_temporary?
    return session_id != 0
  end

  def path(root_url)
    if is_file?
      "#{root_url}files/#{name}"
    else
      "#"
    end
  end


  protected

  def validation_file
    self.original_name = uploaded_file.original_filename
    self.size = uploaded_file.size
    if file_limits
      return false if file_limits[:maxsize] && ( size >= file_limits[:maxsize]*(1024*1024) )
      return false if file_limits[:types] && file_limits[:types].is_a?(Array) && ( ! file_limits[:types].include? extention )
    end
    return true
  end

  def validation_upload
    self.name = "#{Base64.encode64((id * 128).to_s).tr('+/=', '0aZ').strip.delete("\n").upcase}#{rand(36**8).to_s(36).upcase}.#{extention}"
    self.save!
    if is_file?
      begin
        File.open(Rails.root.join("public","files", name), 'wb') do |filetowrite|
          filetowrite.write(uploaded_file.read)
        end
      rescue
        logger.info "File can't be correctly uploaded"
        self.name = ''
      else
        self.uploaded_at = Time.now
      ensure
        self.save!
        self.uploaded_file = nil
      end
    end
    uploaded_at != nil
  end

  def validation_deleted
    if name != ''
      begin
        File.delete(Rails.root.join("public","files", name)) if File.exist? Rails.root.join("public","files", name)
      rescue
        logger.info "File can't be deleted"
        return false
      end
    end
    return true
  end
  
end
