module Admin::SidebarHelper
  def sidebar_link_class(path, **options)
    pattern = if options[:exact]
      Regexp.new("^#{Regexp.escape(path)}$")
    else
      Regexp.new("^#{Regexp.escape(path)}(/|$)")
    end
    active = request.path.match?(pattern)

    if active
      "nav-link active"
    else
      "nav-link text-white"
    end
  end
end
