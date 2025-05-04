angular.module('beamng.apps')
.directive('sumoresetrules', function () {
  return {
    template: `
      <div style="
        display: grid;
        grid-template-columns: 1fr; /* Single column */
        gap: 10px;
        width: 100%;
        background: transparent;
      ">
        <div
          ng-repeat="item in statusItems"
          style="
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 10px;
            box-sizing: border-box;
          ">
          <img
            ng-src="{{item.image}}"
            alt="{{item.name}}"
            ng-style="{
              'opacity': (item.status === 'ok' ? '1' : '0.5')
            }"
            style="
              width: 140px;
              height: 140px;
              transition: opacity 0.2s ease-in-out;
            "
            ng-click="toggleStatus(item)">
        </div>
      </div>
    `,
    restrict: 'EA',
    replace: true,
    link: function (scope) {
      scope.statusItems = [
        { name: 'Car Repair', image: 'carRepairIcon.png', status: 'ok' },
        { name: 'Speed Limit', image: 'speedLimitIcon.png', status: 'ok' },
        { name: 'Safe Zone', image: 'safezoneIcon.png', status: 'ok' }
      ];

      scope.toggleStatus = function(item) {
        item.status = (item.status === 'ok') ? 'not_ok' : 'ok';
      };

      scope.$on('sumoSetRuleStatus', function (event, data) {
        data.rule = data.rule || '';
        data.status = data.status || 'ok';
        for (var i = 0; i < scope.statusItems.length; i++) {
          if (scope.statusItems[i].name === data.rule) {
            scope.statusItems[i].status = data.status;
            break;
          }
        }
      });
    }
  };
});
