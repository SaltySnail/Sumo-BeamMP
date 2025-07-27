angular.module('beamng.apps')
.directive('sumoprecountdown', ['CanvasShortcuts','$timeout', function (CanvasShortcuts, $timeout) {
  return {
    template: `
    <div style="width:100%; height:100%; display:flex; justify-content:center; align-items:center; background:transparent;">
      <h1 style="color:white; font-size:64px; font-family:Roboto; text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.75);" ng-bind="textToShow"></h1>
    </div>
    `,
    replace: true,
    restrict: 'EA',
    link: function (scope) {
      var streamsList = ['SumoText'];

      scope.$applyAsync(function () {
        scope.textToShow = "";
      });

      if (typeof StreamsManager !== 'undefined') {
        StreamsManager.add(streamsList);
      } else {
        console.warn("StreamsManager is undefined, Your Majesty.");
      }

      scope.$on('$destroy', function () {
        if (typeof StreamsManager !== 'undefined') {
          StreamsManager.remove(streamsList);
        }
      });

      scope.$on('sumoPreCountdown', function (event, data) {
        scope.$applyAsync(function () {
          scope.textToShow = data && data.trim() !== "" ? data : "";
        });
      });
    }
  };
}]);
