# -*- coding: utf-8 -*-
require_dependency "advertisement_management/application_controller"

module AdvertisementManagement
  class Susanoo::AdvertisementsController < AdvertisementManagement::ApplicationController
    before_action :enable_engine_required
    before_action :admin_required
    before_action :set_advertisement, only: [:show, :edit, :update, :destroy, :show_file]
    before_action :set_complete_set_message, only: [:index]
    before_action :state_editable, only: %i(edit_state update_state sort finish_sort)

    helper ::Susanoo::VisitorsHelper

    # GET /susanoo/advertisements
    def index
      @pref_ads = Advertisement.pref_advertisements
      @corp_ads = Advertisement.corp_advertisements
      @toppage_ads = Advertisement.toppage_advertisements
    end

    # GET /susanoo/advertisements/1
    def show
    end

    # GET /susanoo/advertisements/new
    def new
      @advertisement = Advertisement.new
    end

    # GET /susanoo/advertisements/1/edit
    def edit
    end

    # POST /susanoo/advertisements
    def create
      @advertisement = Advertisement.new(advertisement_params)

      if @advertisement.save
        return redirect_to susanoo_advertisements_path, notice: t(".success")
      else
        return render action: 'new'
      end
    end

    # PATCH/PUT /susanoo/advertisements/1
    def update
      @advertisement.attributes = advertisement_params
      if @advertisement.save
        return redirect_to susanoo_advertisements_path, notice: t(".success")
      else
        return render action: 'edit'
      end
    end

    # DELETE /susanoo/advertisements/1
    def destroy
      @advertisement.destroy
      return redirect_to susanoo_advertisements_path, notice: t(".success", name: @advertisement.name)
    end

    # === バナー広告ファイルの表示処理
    def show_file
      send_file(@advertisement.image.path)
    end

    # === 公開・非公開の設定画面
    def edit_state
      @pref_ads = Advertisement.pref_advertisements
      @corp_ads = Advertisement.corp_advertisements
      @toppage_ads = Advertisement.toppage_advertisements
      begin
        # 公開設定画面表示前に、広告データをセット
        Advertisement.resetting_list
      rescue => e
        return redirect_to susanoo_advertisements_path
      end
    end

    # === 公開・非公開の設定処理
    def update_state
      if params[:cancel]
        AdvertisementList.destroy_all
        return redirect_to susanoo_advertisements_path, notice: t(".cancel_message")
      else
        AdvertisementList.transaction do
          toppages = []
          params[:advertisement].each do |id, state|
            ad = Advertisement.find(id)
            al = ad.advertisement_list
            al.state = state
            al.save!
          end
          raise ToppageSelectionError if AdvertisementList.toppage_published.count.zero? || AdvertisementList.toppage_published.count > 4
        end
        return redirect_to sort_susanoo_advertisements_path
      end
    rescue ToppageSelectionError
      return redirect_to edit_state_susanoo_advertisements_path, flash: {error: t(".select_toppage")}
    rescue => e
      logger.error("Error while changing advertisement state:" + e.message)
      return redirect_to edit_state_susanoo_advertisements_path
    end

    # === 広告の並び替え
    def sort
      AdvertisementList.transaction do
        ad_lists = AdvertisementList.published.includes(:advertisement).references(:advertisement)
        Advertisement::SIDE_TYPE.each do |k, v|
          column_name = "#{v}_ad_number"
          ads = ad_lists.merge(Advertisement.where("advertisements.side_type = ?", k)).order("advertisement_lists.#{column_name}")
          ads.map.with_index do |ad, i|
            ad.send("#{column_name}=", i)
            ad.save!
          end
          self.instance_variable_set(:"@#{v}_ads", ads)
        end
      end
    end

    # === Ajax 広告の並び替え保存処理
    def update_sort
      st = Advertisement::SIDE_TYPE.values
      type = params[:side_type]
      other_type = st.reject{|s|s == params[:side_type]}.first
      AdvertisementList.transaction do
        ads = params["item"].map.with_index do |id, position|
          ad = AdvertisementList.find(id)
          ad.update!("#{type}_ad_number" => position)
          ad
        end
        self.instance_variable_set(:"@#{type}_ads", ads)
      end
      self.instance_variable_set(:"@#{other_type}_ads", AdvertisementList.send("#{other_type}_published"))
      return render("sort")
    rescue => e
      logger.error("Error while sorting corp ads." + e.message)
      sort
      return render("sort")
    end

    # === [POST] 広告の並び替え完了
    def finish_sort
      if params[:save]
        Job.create(action: 'move_banner_images', datetime: Time.now)
      elsif params[:cancel]
        flash[:notice] = t(".cancel_message")
        AdvertisementList.destroy_all
      end
      return redirect_to susanoo_advertisements_path
    rescue => e
      logger.error("Error while updating advertisement state:" + e.message)
      return redirect_to susanoo_advertisements_path
    end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_advertisement
      @advertisement = Advertisement.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def advertisement_params
      params[:advertisement].permit(:name, :advertiser, :state, :side_type, :image_file,
        :begin_date, :end_date, :description, :description_link, :image, :alt, :url, :show_in_header)
    end

    def set_complete_set_message
      notice = 
        if Advertisement.advertisement_job_exists?
          t(".exist_banner_job")
        elsif !Advertisement.toppage_advertisements.exists?
          t(".toppage_advertisements_not_found")
        end
      flash.now[:notice] = notice if notice
    end

    def state_editable
      unless Advertisement.state_editable?
        redirect_to susanoo_advertisements_path
      end
    end
  end
end
