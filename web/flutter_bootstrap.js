// The Flutter web entrypoint
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    // Remove loading screen
    const loading = document.getElementById('loading');
    if (loading) {
      loading.style.opacity = '0';
      loading.style.transition = 'opacity 0.3s ease';
      setTimeout(() => loading.remove(), 300);
    }
  }
});
