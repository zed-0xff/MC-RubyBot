package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.screen.ScreenHandler;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.screen.slot.SlotActionType;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.screen.slot.Slot;
import net.minecraft.util.collection.DefaultedList;
import net.minecraft.inventory.Inventory;

import java.util.OptionalInt;

@Mixin(ScreenHandler.class)
public class MixinScreenHandler {
    @Inject(
            method = "setStackInSlot(IILnet/minecraft/item/ItemStack;)V",
            at = @At("HEAD")
    )
    private void setStackInSlot(int slot, int revision, ItemStack stack, CallbackInfo ci) {
        if ( ExampleMod.LOGGER != null ){
            if ( slot == 0 && stack != null && stack.getCount() == 0 && stack.getItem().equals(Items.AIR) ) {
                return;
            }
            ExampleMod.LOGGER.info("[d] setStackInSlot(" + slot + ", " + revision + ", " + stack + ") syncId=" + ((ScreenHandler)(Object)this).syncId);
        }
    }

//    @Inject(
//            method = "internalOnSlotClick(IILnet/minecraft/screen/slot/SlotActionType;Lnet/minecraft/entity/player/PlayerEntity;)V",
//            at = @At("HEAD"),
//            cancellable = true
//    )
//    private void onSlotClick(int slotIndex, int button, SlotActionType actionType, PlayerEntity player, CallbackInfo ci) {
//        ExampleMod.LOGGER.info("[d] onSlotClick " + slotIndex);
//        if ( slotIndex == 37 ) {
//            ci.cancel();
//        }
//    }

//    @Shadow
//    @Final
//    DefaultedList<Slot> slots;

//    @Inject(
//            method = "getSlotIndex(Lnet/minecraft/inventory/Inventory;I)Ljava/util/OptionalInt;",
//            at = @At("HEAD"),
//            cancellable = true
//    )
//    private void getSlotIndex(Inventory inventory, int index, CallbackInfoReturnable<OptionalInt> cir) {
//        ExampleMod.LOGGER.info("[d] getSlot " + index);
//        if ( index == 37 ) {
//            cir.setReturnValue(OptionalInt.of(10));
//        }
//    }

}
