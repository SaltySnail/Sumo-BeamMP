angular.module('beamng.apps')
.directive('sumoscoreboard', ['CanvasShortcuts', '$timeout', function (CanvasShortcuts, $timeout) {
    return {
        template: `
            <div ng-if="visible" id="scoreboardDiv"
                 style="position:absolute;
                        top:0; left:0;
                        width:100%; height:100%;
                        background:rgba(0, 0, 0, 0.7);
                        color:white;
                        padding:10px;
                        box-sizing:border-box;">
                <table id="scoreboardTable"
                       style="width:100%;
                              border-collapse:collapse;
                              font-size:1.2em;">
                    <thead>
                        <tr>
                            <th style="text-align:left; padding:8px;">Player</th>
                            <th style="text-align:right; padding:8px;">Round</th>
                            <th style="text-align:right; padding:8px;">Total</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Teams display -->
                        <tr ng-repeat-start="team in teams" ng-if="teams.length"
                            style="background:{{team.color}}; font-weight:bold;">
                            <td colspan="2" style="padding:8px;">{{team.name}}</td>
                        </tr>
                        <tr ng-repeat="p in team.players" ng-if="teams.length"
                            ng-class="{'winner': p.name === winner}"
                            style="border-top:1px solid rgba(255,255,255,0.2);">
                            <td style="padding:8px;">{{p.name}}</td>
                            <td style="padding:8px; text-align:right;">{{p.score}}</td>
                        </tr>
                        <tr ng-repeat-end ng-if="teams.length"></tr>

                        <!-- Fallback individual players -->
                        <tr ng-repeat="player in players | orderBy:['-totalScore', '-roundScore']"                            
                            ng-class="{'round-winner': player.isRoundWinner}"
                            style="padding: 8px;">
                            <td style="padding: 8px;">
                                {{player.name}} <span ng-if="player.isRoundWinner">👑</span>
                            </td>
                            <td style="padding: 8px; text-align:right;">{{player.roundScore}}</td>
                            <td style="padding: 8px; text-align:right;">{{player.totalScore}}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        `,
        replace: true,
        restrict: 'EA',
        link: function (scope, element, attrs) {
            // Visibility
            scope.visible = false;
            // Data structures
            scope.players = [];
            scope.teams = [];
            scope.winner = null;

            // Spawn (show) the scoreboard
            scope.$on('scoreboardSpawn', function () {
                scope.visible = true;
                scope.$applyAsync();
            });

            // Remove (hide) the scoreboard
            scope.$on('scoreboardRemove', function () {
                scope.visible = false;
                scope.$applyAsync();
            });

            // Set individual player scores (clears teams)
            scope.$on('scoreboardSetScores', function (event, data) {
                scope.players = Array.isArray(data.players) ? data.players : [];
                scope.teams = [];
                scope.$applyAsync();
            });

            // Set team-based scores (clears individual players)
            scope.$on('scoreboardSetTeams', function (event, data) {
                /* data.teams = [ { name: string, color: string, players: [{name,score},...] }, ... ] */
                scope.teams = Array.isArray(data.teams) ? data.teams : [];
                scope.players = [];
                scope.$applyAsync();
            });

            // Select a winner by name
            scope.$on('scoreboardSelectOverallWinner', function (event, data) {
                scope.winner = data.winner || null;
                scope.$applyAsync();
            });

            // Clear all data
            scope.$on('scoreboardClear', function () {
                scope.players = [];
                scope.teams = [];
                scope.winner = null;
                scope.$applyAsync();
            });

            // Handle app resize if needed
            scope.$on('app:resized', function (event, data) {
                // Adjust styling or table dimensions here
            });
        }
    };
}]);
