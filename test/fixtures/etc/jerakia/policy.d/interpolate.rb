policy :interpolate do
  lookup :default do
    datasource :file, {
      :docroot    => "test/fixtures/var/lib/jerakia/data",
      :enable_caching => true,
      :searchpath => [
        "host/#{scope[:hostname]}",
        "env/#{scope[:env]}",
        "common",
      ],
    }

    filter :interpolate, scope: scope

  end
end

