package funkin.ui.debug.charting.dialogs;

import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.ui.debug.charting.components.ChartEditorDifficultyItem;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/generate-difficulty.xml"))
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorGenerateDifficultyDialog extends ChartEditorBaseDialog
{
  public function new(state2:ChartEditorState, params2:DialogParams)
  {
    super(state2, params2);

    dialogCancel.onClick = function(_) {
      hideDialog(DialogButton.CANCEL);
    }

    dialogGenerate.onClick = function(_) {
      generateDifficulties();
      hideDialog(DialogButton.APPLY);
    };

    difficultyView.addComponent(new ChartEditorDifficultyItem(difficultyView));

    chartEditorState.isHaxeUIDialogOpen = true;
  }

  function generateDifficulties():Void
  {
    var refDifficultyId:String = chartEditorState.selectedDifficulty;
    for (item in difficultyView.findComponents(null, ChartEditorDifficultyItem))
    {
      if (!item.difficultyFrame.hidden && item.difficultyTextField.value != null && item.difficultyTextField.value.length != 0)
      {
        chartEditorState.generateChartDifficulty(
          {
            refDifficultyId: refDifficultyId,
            difficultyId: item.difficultyTextField.value.toLowerCase(),
            algorithm: RemoveNthTooClose(item.nStepper.value),
            scrollSpeed: item.scrollSpeedStepper.value
          });
        chartEditorState.selectedDifficulty = item.difficultyTextField.value.toLowerCase();
      }
    }
    chartEditorState.selectedDifficulty = refDifficultyId;
  }

  // TODO: this should probably not be in the update function
  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    dialogGenerate.disabled = cast(difficultyView.getComponentAt(0), ChartEditorDifficultyItem).difficultyFrame.hidden;
  }

  public override function onClose(event:DialogEvent):Void
  {
    super.onClose(event);

    chartEditorState.isHaxeUIDialogOpen = false;
  }

  public override function lock():Void
  {
    super.lock();
    this.dialogCancel.disabled = true;
  }

  public override function unlock():Void
  {
    super.unlock();
    this.dialogCancel.disabled = false;
  }

  public static function build(state:ChartEditorState, ?closable:Bool, ?modal:Bool):ChartEditorGenerateDifficultyDialog
  {
    var dialog = new ChartEditorGenerateDifficultyDialog(state,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
