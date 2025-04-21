class PostsController < ApplicationController
  require "zip"

  before_action :authenticate_user!, except: [ :index, :show, :new, :create, :handle_slug, :redirect_posts, :download_as_zip ]
  before_action :set_post, only: %i[ show handle_slug edit update destroy ]
  before_action :require_permission, only: [ :edit, :update, :destroy ]

  # GET /posts or /posts.json
  def index
    @pagy, @posts = pagy_countless(@q.result(distinct: true)
                          .where(status: "public")
                          .where(redirect_url: [ nil, "" ])
                          .order("created_at DESC"),
                    items: 30)
    # Group posts by date
    @posts_by_date = @posts.group_by { |post| post.created_at.to_date }
    @post = Post.new

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def redirect_posts
    @posts = @q.result(distinct: true).where(status: "public").where.not(redirect_url: [ nil, "" ]).order("created_at DESC")
    # Group posts by date
    @posts_by_date = @posts.group_by { |post| post.created_at.to_date }
    @post = Post.new
  end

  def user_posts
    @posts = @q.result(distinct: true).where(user_id: current_user.id).order("created_at DESC")
    # Group posts by date
    @posts_by_date = @posts.group_by { |post| post.created_at.to_date }
    @post = Post.new
  end

  # GET /posts/1 or /posts/1.json
  def show
    # return redirect_to @post.redirect_url, allow_other_host: true if @post.redirect_url.present?

    if @post.status == "private" && current_user != @post.user
      redirect_to root_path, notice: "No permission. This post is private."
    else
      @url = request.base_url + "/" + @post.slug
    end
  end

  def handle_slug
    return redirect_to @post.redirect_url, allow_other_host: true if @post.redirect_url.present?

    return redirect_to root_path, alert: "Post not found." if @post.nil?

    redirect_to @post
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    if current_user
      @user = current_user
    else
      @user = User.find_by(username: post_params[:username])
    end

    @id = @user.id unless @user.nil?

    @post = Post.new(post_params.except(:username).merge(user_id: @id))

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params.except(:username))
        format.html { redirect_to @post, notice: "Post was successfully updated." }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to posts_path, status: :see_other, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /posts/1/download_as_zip
  def download_as_zip
    post = Post.find(params[:id])

    files = if params[:file_ids].present?
              post.files.select { |f| params[:file_ids].include?(f.id.to_s) }
    else
              post.files
    end

    compressed_filestream = Zip::OutputStream.write_buffer do |zos|
      files.each do |file|
        zos.put_next_entry file.filename.to_s
        zos.write file.download
      end
    end

    compressed_filestream.rewind
    send_data compressed_filestream.read,
              filename: "post#{post.id}.zip",
              type: "application/zip"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find_by_slug(params[:slug])
      @post = Post.find(params[:id]) if @post.nil?
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:slug, :title, :description, :status, :username, :redirect_url, files: [])
    end

    def require_permission
      if current_user != Post.find(params[:id]).user && !current_user.admin?
        redirect_to root_path
        flash[:notice] = "No permission"
      end
    end
end
