angular.module('beamng.stuff')
.directive('sumomenu', ['CanvasShortcuts','$timeout', function (CanvasShortcuts, $timeout) {
  return {
    template: `
      <div 
        style="
          background: rgba(0,0,0,0.6);
          padding: 15px;
          width: 200px;
          border-radius: 8px;
          color: #fff;
          font-family: sans-serif;
        ">
        
        <!-- Button Row -->
        <div style="margin-bottom:12px; width:100%;">
          <button
            ng-click="spectateAlivePlayer()"
            style="
              width:100%;
              padding:8px;
              border:none;
              border-radius:4px;
              background:#444;
              color:#fff;
              cursor:pointer;
              transition:background 0.2s;
            "
            ng-init="pressBtn=false"
            ng-mousedown="pressBtn=true"
            ng-mouseup="pressBtn=false"
            ng-style="{'background': pressBtn ? '#555' : '#444'}">
            Spectate Alive Player
          </button>
        </div>
        
        <!-- Checkbox Row 1 -->
        <div style="margin-bottom:12px;">
          <label style="display:flex; align-items:center; font-size:14px; cursor:pointer;">
            <input
              type="checkbox"
              ng-model="settings.joinNextRound"
              ng-change="setJoinNextRound(settings.joinNextRound)"
              style="margin-right:8px; width:16px; height:16px; cursor:pointer;" />
            Join Next Round
          </label>
        </div>
        
        <!-- Checkbox Row 2 -->
        <div>
          <label style="display:flex; align-items:center; font-size:14px; cursor:pointer;">
            <input
              type="checkbox"
              ng-model="settings.autoSpectate"
              ng-change="setAutoSpectate(settings.autoSpectate)"
              style="margin-right:8px; width:16px; height:16px; cursor:pointer;" />
            Auto Spectate
          </label>
        </div>
        
      </div>
    `,
    restrict: 'E',
    link: function(scope) {
      // Initialize settings object
      scope.settings = {
        joinNextRound: false,
        autoSpectate: true
      };

      scope.$on('setSumoMenuSettings', function(_, settings) {
        scope.settings = settings;
        scope.$apply();
      });

      //scope.$on('setSumoMenuSettingsAutoSpectate', function(autoSpectate)) {
      //  scope.settings.autoSpectate = autoSpectate;
       // scope.$apply();
      //};

     // scope.$on('setSumoMenuSettingsJoinNextRound', function(joinNextRound)) {
      //  scope.settings.joinNextRound = joinNextRound;
      //  scope.$apply();
      //};

      scope.spectateAlivePlayer = function() {
        bngApi.engineLua(
          'extensions.Sumo.sumoSpectateAlivePlayer()',
          (res) => { console.log('spectateAlive OK', res); }
        );
      };

      scope.setJoinNextRound = function(state) {
        bngApi.engineLua(
          `extensions.Sumo.setJoinNextRound(${state})`,
          (res) => { console.log('setJoinNextRound OK', res); }
        );
      };

      scope.setAutoSpectate = function(state) {
        bngApi.engineLua(
          `extensions.Sumo.setAutoSpectate(${state})`,
          (res) => { console.log('setAutoSpectate OK', res); }
        );
      };

      bngApi.engineLua('extensions.Sumo.getSumoMenuState()');
    }
  };
}]);
