angular.module('beamng.apps')
.directive('sumoresetrules', function () {
  return {
    template: `
      <div
        style="
          display: grid;
          grid-template-columns: 1fr 1fr;   /* equal-width columns */
          gap: 10px;
          width: 100%;
          background: transparent;
        ">
        <!-- Left column: main icons -->
        <div
          style="
            display: flex;
            flex-direction: column;
            gap: 10px;
            align-items: center;            /* center icons horizontally */
          ">
          <img
            ng-repeat="item in statusItems"
            ng-src="{{item.image}}"
            alt="{{item.name}}"
            style="
              width: 100%;                    /* fill column width */
              max-width: 100%;
              object-fit: contain;
            ">
        </div>
        <!-- Right column: status icons -->
        <div
          style="
            display: flex;
            flex-direction: column;
            gap: 10px;
            align-items: center;            /* center icons horizontally */
          ">
          <img
            ng-repeat="item in statusItems"
            ng-src="{{ item.status === 'ok' ? 'checkmarkIcon.png' : 'crossIcon.png'}}"
            alt="Status Icon"
            style="
              width: 100%;                    /* fill column width */
              max-width: 80px;                /* cap icon size */
              height: 80px;
              cursor: pointer;
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
