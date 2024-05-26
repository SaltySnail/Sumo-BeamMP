angular.module('beamng.apps')
.directive('sumocountdown', ['CanvasShortcuts','$timeout', function (CanvasShortcuts, $timeout) {
  return {
    template:  `
    <div id="sumocountdownDiv" style="max-height:100%; width:100%; margin:0px; background:transparent;" layout="row" layout-align="center left" layout-wrap> 
        <div id="sumocountdowncanvDiv" style="position:absolute; marginTop:0; marginLeft:0; width:100%; height:100%;">
            <canvas id="sumocountdowncanv" style="width:100%; height:100%;" width="500" height="500"></canvas>
        </div>
    </div>
    `,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
        var streamsList = ['Sumo'];
        var canvas;
        var ctx;
        var timerID;
        StreamsManager.add(streamsList);
        scope.$on('$destroy', function () {
            StreamsManager.remove(streamsList);
        });

        function clearCanvas() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            clearInterval(timerID);
        }
        scope.$on('sumoCountdown', function (event, data) {              
            canvas = document.getElementById("sumocountdowncanv");
            ctx = canvas.getContext("2d");
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            // Draw a semi-transparent yellow circle
            ctx.beginPath();
            ctx.arc(250, 250, 100, 0, 2 * Math.PI);
            if (data == '0') {
                ctx.fillStyle = "rgba(0, 230, 0, 0.4)";
            } else {
                ctx.fillStyle = "rgba(230, 230, 0, 0.4)";
            }
            ctx.fill();
            // Print white numbers 1-9 in the middle of the circle
            ctx.font = "bold 75pt Roboto";
            ctx.fillStyle = "white";
            if (data == '0') {
                ctx.fillText("GO", 175, 280);
                timerID = setInterval(clearCanvas, 1000);
            } else {
                ctx.fillText(data, 225, 280);
            }
        });            
        // Wait for the DOM to be fully loaded
        document.addEventListener('DOMContentLoaded', function() {
            // Wrap canvas initialization inside $timeout to ensure it runs after the DOM is loaded
            canvas = document.getElementById('circleCanvas');
            if (!canvas) {
                console.error("Canvas element not found.");
                return;
            }

            updateTime();
        });
    }
  };
}])