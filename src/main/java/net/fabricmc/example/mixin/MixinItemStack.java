package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;

// not works
@Mixin(ItemStack.class)
public abstract class MixinItemStack
{
    @Shadow
    public abstract Item getItem();

    @Inject(method = "getMaxCount", at = @At("HEAD"), cancellable = true)
    public void getMaxCount(CallbackInfoReturnable<Integer> ci)
    {
        ExampleMod.LOGGER.info("[d] getMaxStackSize");
    }
}
