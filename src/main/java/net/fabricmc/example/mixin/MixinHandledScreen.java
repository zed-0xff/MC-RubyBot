package net.fabricmc.example.mixin;

import net.fabricmc.example.HudOverlay;

import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.gui.DrawableHelper;
import net.minecraft.client.gui.screen.Screen;
//import net.minecraft.client.gui.screen.ingame.HandledScreen;
import net.minecraft.client.util.math.MatrixStack;

@Mixin(Screen.class)
public class MixinHandledScreen {

    @Inject(method = "render", at = @At("RETURN"))
    private void onGameOverlayPost(MatrixStack matrixStack, int mouseX, int mouseY, float delta, CallbackInfo ci)
    {
        matrixStack.push();
        // zLevel - should be greater than ItemStack one, and less than Tooltip
        // 200: regular items
        // 2xx: animated (enchanted) items
        //      <-- we should draw here
        // 300: tooltips
        matrixStack.translate(0, 0, 280);
        HudOverlay.onRenderGameOverlayPost(matrixStack, null, (Screen)(Object)this);
        matrixStack.pop();
    }
}
