#coding: UTF-8
class Media < ActiveRecord::Base
  require "fileutils"

  #scope :old, lambda{ where('created_at <= ? and session_id > 0', Date.today-4.days) }
  scope :old, lambda{ Media.joins("LEFT OUTER JOIN sessions ON (medias.session_id = sessions.id)").where("medias.session_id > 0").where("sessions.id is null") }

  has_one :note, dependent: :destroy
  belongs_to :session
  
  attr_accessible :session_id, :uploaded_file, :file_limits, :user_id
  attr_protected  [:name, :original_name, :uploaded_at, :size], :as => :admin
  attr_accessor   :file_limits, :uploaded_file
  accepts_nested_attributes_for :note

  before_validation :validation_isfile, on: :create
  before_create     :validation_file
  after_create      :validation_upload
  after_create      :validation_default_note
  before_destroy    :validation_deleted

  def save_and_associate_to_user!(user_id)
    self.user_id = user_id
    self.session_id = 0
    self.save!
  end

  def extention
    if original_name.index(".")
      original_name.split(".").last.downcase
    else
      ""
    end
  end
  
  def is_file?
    return (uploaded_at != nil && name != '' && name != nil) || (uploaded_file.is_a?(ActionDispatch::Http::UploadedFile) )
  end

  def is_image?
    ["jpg", "jpeg", "gif", "png"].include? extention
  end

  def is_temporary?
    return session_id != 0
  end

  def is_uploaded?
    id != nil && is_file?
  end

  def path(root_url)
    if is_file?
      "#{root_url}files/#{name}"
    else
      "#"
    end
  end

  def validate_description!
    if self.note.description == ''
      errors.add(:note, "La description doit être renseignée")
      return false
    end
    true
  end

  def validate_record_exist!
     if (self.id == nil || self.id == 0)
       errors.add(:media, "Votre fichier n'est plus disponible sur le serveur, merci de le télécharger à nouveau")
       return false
     end
     true
  end

  protected

  def validation_isfile
    errors.add(:media, 'Aucun fichier a uploader') unless is_file?
  end

  def validation_file
    self.original_name = uploaded_file.original_filename
    self.size = uploaded_file.size
    if file_limits
      if file_limits[:maxsize] && ( size >= file_limits[:maxsize]*(1024*1024) )
        errors.add(:media, "La taille de votre fichier est trop grande (#{file_limits[:maxsize]}Mo max)")
        return false
      end      
      if file_limits[:types] && file_limits[:types].is_a?(Array) && ( ! file_limits[:types].include? extention )
        errors.add(:media, "Le type de fichier est incorrect (doit être #{file_limits[:types].join(',')})")
        return false
      end
    end
    return true
  end

  def validation_upload
    self.name = "#{Base64.encode64((id * 128).to_s).tr('+/=', '0aZ').strip.delete("\n").upcase}#{rand(36**8).to_s(36).upcase}.#{extention}"
    if Media.where(name: self.name).count > 0
      self.name = ''
      self.uploaded_file = nil
      logger.info "A new name for a file already exist in database (name field should be uniqueness at create step - Error Code E1)"
      errors.add(:media, "Ooops ! Votre fichier n'a pas été téléchargé correctement. Merci de recommencer (Code d'erreur E1)")
    end
    if is_file? && self.name != ''
      self.save!
      begin
        File.open(Rails.root.join("public","files", name), 'wb') do |filetowrite|
          filetowrite.write(uploaded_file.read)
        end
      rescue
        logger.info "File can't be writted (Error Code E2)"
        self.name = ''
      else
        self.uploaded_at = Time.now
      ensure
        self.save!
        self.uploaded_file = nil
      end
      errors.add(:media, "Ooops ! Votre fichier n'a pas été téléchargé correctement. Merci de recommencer (Code d'erreur E2)") if name == ''
    end    
    uploaded_at != nil
  end

  def validation_deleted
    if name != '' && name != nil
      begin
        File.delete(Rails.root.join("public","files", name)) if File.exist? Rails.root.join("public","files", name)
      rescue
        logger.info "File can't be deleted"
        return false
      end
    end
    true
  end

  def validation_default_note
    self.build_note unless self.note
    self.note.save!
  end
  
end
