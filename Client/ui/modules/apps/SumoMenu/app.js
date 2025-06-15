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

        <!-- Join Next Round -->
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

        <!-- Spectating Player -->
        <div style="margin-bottom:12px;">
          <div style="font-size:14px; margin-bottom:6px;">Spectating:</div>
          <div style="display:flex; justify-content:space-between; align-items:center;">
            <button ng-click="prevPlayer()" style="background:none; border:none; color:white; font-size:20px;">&#x276E;</button>
            <div style="flex-grow:1; text-align:center;">{{ currentSpectatingPlayer || 'Select player' }}</div>
            <button ng-click="nextPlayer()" style="background:none; border:none; color:white; font-size:20px;">&#x276F;</button>
          </div>
        </div>

        <!-- Stop Spectating Button -->
        <div style="margin-bottom:12px;">
          <button
            ng-click="stopSpectating()"
            style="
              width:100%;
              padding:8px;
              border:none;
              border-radius:4px;
              background:#444;
              color:#fff;
              cursor:pointer;
              transition:background 0.2s;
            ">
            Stop spectating
          </button>
        </div>

        <!-- Auto Spectate -->
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
      scope.settings = {
        joinNextRound: false,
        autoSpectate: true
      };

      scope.players = [];
      scope.currentPlayerIndex = 0;
      scope.currentSpectatingPlayer = '';

      // Receive player list from Lua
      scope.$on('setSumoPlayerList', function(_, players) {
        scope.players = players || [];
        scope.updateSpectatingDisplay();
        scope.$apply();
      });

      scope.$on('spectatePlayerByName', function(_, playerName) {
        if (Array.isArray(scope.players)) {
          const index = scope.players.findIndex(p => p === playerName);
          if (index !== -1) {
            scope.currentPlayerIndex = index;
            scope.updateSpectatingDisplay();
            console.log('Spectating player:', playerName);
          } else {
            console.warn('Player not found in alive list:', playerName);
          }
        } else {
          console.error('Player list is not an array:', scope.players);
        }
        scope.$apply();
      });

      scope.prevPlayer = function() {
        if (scope.players.length === 0) return;
        scope.currentPlayerIndex = (scope.currentPlayerIndex - 1 + scope.players.length) % scope.players.length;
        scope.updateSpectatingDisplay();
      };

      scope.nextPlayer = function() {
        if (scope.players.length === 0) return;
        scope.currentPlayerIndex = (scope.currentPlayerIndex + 1) % scope.players.length;
        scope.updateSpectatingDisplay();
      };

      scope.updateSpectatingDisplay = function() {
        scope.currentSpectatingPlayer = scope.players[scope.currentPlayerIndex] || '';
        bngApi.engineLua(`extensions.Sumo.spectatePlayer("${scope.currentSpectatingPlayer}")`);
      };

      scope.stopSpectating = function() {
        scope.currentSpectatingPlayer = '';
        bngApi.engineLua(`extensions.Sumo.sumoStopSpectating()`);
      };

      scope.setJoinNextRound = function(state) {
        bngApi.engineLua(`extensions.Sumo.setJoinNextRound(${state})`);
      };

      scope.setAutoSpectate = function(state) {
        bngApi.engineLua(`extensions.Sumo.setAutoSpectate(${state})`);
      };

      bngApi.engineLua('extensions.Sumo.getSumoMenuState()');
      bngApi.engineLua('extensions.Sumo.getPlayerList()'); // Trigger Lua to send the list
    }
  };
}]);

