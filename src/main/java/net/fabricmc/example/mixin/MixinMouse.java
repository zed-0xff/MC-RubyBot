package net.fabricmc.example.mixin;

import net.fabricmc.example.handlers.ActionHandler;
import net.fabricmc.example.ExampleMod;

import org.lwjgl.glfw.GLFW;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.Mouse;
import net.minecraft.client.util.Window;

@Mixin(Mouse.class)
public abstract class MixinMouse
{
    @Inject(method = "onMouseButton", cancellable = true,
            at = @At(value = "FIELD", target = "Lnet/minecraft/client/MinecraftClient;IS_SYSTEM_MAC:Z", ordinal = 0))
    private void hookOnMouseClick(long handle, final int button, final int action, int mods, CallbackInfo ci)
    {
        if ( action == GLFW.GLFW_RELEASE && ActionHandler.suppressButtonRelease ) {
            ExampleMod.LOGGER.info("[d] button=" + button + ", action=" + action + ", mods=" + mods);
            ActionHandler.suppressButtonRelease = false;
            ci.cancel();
        }
    }
}
