angular.module('beamng.apps')
.directive('sumoresetbar', ['CanvasShortcuts', '$timeout', function (CanvasShortcuts, $timeout) {
    return {
        template: `
            <div id="resetbarContainer" style="width: 100%; height: 30px; position: relative; display: none;">
                <div style="width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.3);">
                    <div id="resetbarFill" style="height: 100%; width: 0%; background-color: white; transition: width 0.1s linear;"></div>
                </div>
            </div>
        `,
        replace: true,
        restrict: 'EA',
        link: function (scope, element, attrs) {
            var streamsList = ['ResetHold'];
            StreamsManager.add(streamsList);
            scope.$on('$destroy', function () {
                StreamsManager.remove(streamsList);
            });

            var fillElement = null;
            var containerElement = null;

            $timeout(() => {
                fillElement = document.getElementById('resetbarFill');
                containerElement = document.getElementById('resetbarContainer');
            });

            function syncResetProgress(value) {
                value = Math.min(Math.max(value, 0), 1);
                if (!fillElement || !containerElement) return;

                // Show or hide container based on value
                containerElement.style.display = value > 0 ? 'block' : 'none';

                // Update fill width and color
                fillElement.style.width = (value * 100) + '%';
                fillElement.style.backgroundColor = 'white';
            }

            scope.$on('resetSyncProgress', function (event, data) {
                syncResetProgress(data);
            });
        }
    };
}]);
