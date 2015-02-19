#coding: UTF-8
class MediasController < ApplicationController
  # Warning :
  # Media is translated to Medium by Rails.
  # Update the file "config\initializers\inflections.rb" by adding thise line :
  # inflect.irregular "media", "medias"
  #
  # To use session in DB, add this line in the file "config\initializers\session_store.rb" :
  # Downloader::Application.config.session_store :active_record_store
  # And execute the script : rails generate session_migration
  # Finish with a rake db:migrate
  # And activate the protect_from_forgery (see application_controler and added lines)
  # You can add method #session_id and his helper_method to access directly to session_id in database
  #

  before_filter :check_csrf!, only: [:create, :update, :destroy]

  # GET /medias
  # GET /medias.json
  def index
    @medias = Media.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @medias }
    end
  end

  # GET /medias/1
  # GET /medias/1.json
  def show
    @media = Media.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @media }
    end
  end

  # GET /medias/new
  # GET /medias/new.json
  def new
    @media = Media.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @media }
    end
  end

  # GET /medias/1/edit
  def edit
    @media = Media.find(params[:id])
  end

  # POST /medias
  # POST /medias.json
  def create
    @media = Media.new(uploaded_file: params[:file_tag], session_id: session_id,
                       file_limits: {maxsize: 3, types: ["jpg","jpeg","png","gif"]})
    if params[:file_id]
      if @media.is_file? || params["file_tag_replace_file_id"] == "1"
        (old_media = Media.where(id: params[:file_id]).where(session_id: session_id).first) && old_media.destroy
        params[:file_id] = nil
      else
        @media = Media.where(id: params[:file_id]).where(session_id: session_id).first || Media.new
      end
    end
    @media.build_note && @media.note.description = params[:file_description]
    # Conserver cette ordre :
    @media.validate_record_exist! if params[:file_id] # 1/ Tester si on récupère un fichier et qu'on remonte 0 record
    @media.save if @media.errors.count == 0           # 2/ Entamer une sauvegarde si pas d'erreur (test précédent montant 0 error)
    @media.validate_description!                      # Optionnel : Tout autre traitement, on a le fichier maintenant
    respond_to do |format|
      if @media.is_uploaded? && @media.errors.count == 0 && @media.save_and_associate_to_user!(session_id*100)
        format.html { redirect_to @media, notice: 'Media was successfully created.' }
        format.json { render json: @media, status: :created, location: @media }
      else
        unless @media.is_uploaded? # rollback if no file uploaded (validation failed)
          @file_description = @media.note.description if @media.note
          @media.destroy
        end
        format.html { render action: "new" }
        format.json { render json: @media.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /medias/1
  # PUT /medias/1.json
  def update
    @media = Media.find(params[:id])

    respond_to do |format|
      if @media.update_attributes(params[:media], :as => :admin)
        format.html { redirect_to @media, notice: 'Media was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @media.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /medias/1
  # DELETE /medias/1.json
  def destroy
    @media = Media.find(params[:id])
    @media.destroy

    respond_to do |format|
      format.html { redirect_to medias_url, notice: 'Le fichier a été supprimé' }
      format.json { head :no_content }
    end
  end


  protected

  def check_csrf!
    # See http://www.learningjquery.com/2010/03/detecting-ajax-events-on-the-server/
    # Do not check csrf to API call like json request (Use tocken + encrypted connection).
    check_csrf unless request.xhr? && request.json?
  end
end
