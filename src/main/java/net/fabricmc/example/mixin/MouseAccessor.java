package net.fabricmc.example.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

import net.minecraft.client.Mouse;

@Mixin(Mouse.class)
public interface MouseAccessor {
    @Invoker
    void invokeOnMouseButton(long window, int button, int action, int mods);
}
