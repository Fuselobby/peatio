module Admin::CampaignHelper
  def sort_link(title, column)
    @sort_dir = column == params[:sort_col] && params[:sort_dir] == "asc" ? "desc" : "asc"

    render partial: "shared/admin/sort_link", locals: { title: title, column: column }
  end
end
