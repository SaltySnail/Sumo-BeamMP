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
            ng-mouseenter="hoverBtn=true"
            ng-mouseleave="hoverBtn=false"
            ng-style="hoverBtn && {'background':'#555'}">
            Spectate Alive Player
          </button>
        </div>
        
        <!-- Checkbox Row 1 -->
        <div style="margin-bottom:12px;">
          <label style="display:flex; align-items:center; font-size:14px; cursor:pointer;">
            <input
              type="checkbox"
              ng-model="joinNextRound"
              ng-change="setJoinNextRound(joinNextRound)"
              style="margin-right:8px; width:16px; height:16px; cursor:pointer;" />
            Join Next Round
          </label>
        </div>
        
        <!-- Checkbox Row 2 -->
        <div>
          <label style="display:flex; align-items:center; font-size:14px; cursor:pointer;">
            <input
              type="checkbox"
              ng-model="autoSpectate"
              ng-change="setAutoSpectate(autoSpectate)"
              style="margin-right:8px; width:16px; height:16px; cursor:pointer;" />
            Auto Spectate
          </label>
        </div>
        
      </div>
    `,
    restrict: 'E',
    link: function(scope) {
      scope.optionA = false;
      scope.optionB = false;

      scope.spectateAlivePlayer = function() {
        bngApi.engineLua(
          'Sumo.sumoSpectateAlivePlayer()',
          (res) => { console.log('spectateAlive OK', res); }
        );
      };

      scope.setJoinNextRound = function(state) {
        bngApi.engineLua(
          `Sumo.setJoinNextRound(${state})`,
          (res) => { console.log('setJoinNextRound OK', res); }
        );
      };

      scope.setAutoSpectate = function(state) {
        bngApi.engineLua(
          `Sumo.setAutoSpectate(${state})`,
          (res) => { console.log('setAutoSpectate OK', res); }
        );
      };
    }
  };
}]);